const axios = require('axios');

const GITHUB_TOKEN = process.env.GITHUB_TOKEN;
const REPO_OWNER = 'phiptech';
const REPO_NAME = 'construction-project';
const RELEASE_TAG = process.env.GITHUB_REF.split('/').pop(); // 获取 Release 标签
const MILESTONE_TITLE = RELEASE_TAG; // Milestone 标题与 Release 标签一致

async function getMilestoneId() {
  const url = `https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/milestones`;
  const response = await axios.get(url, {
    headers: {
      Authorization: `token ${GITHUB_TOKEN}`,
      'User-Agent': 'Node.js',
    },
  });

  const milestone = response.data.find((m) => m.title === MILESTONE_TITLE);
  if (!milestone) {
    throw new Error(`Milestone "${MILESTONE_TITLE}" not found`);
  }
  return milestone.number; // Milestone ID
}

async function associateMilestoneWithRelease() {
  try {
    const milestoneId = await getMilestoneId();

    // 获取 Release ID
    const releaseUrl = `https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/tags/${RELEASE_TAG}`;
    const releaseResponse = await axios.get(releaseUrl, {
      headers: {
        Authorization: `token ${GITHUB_TOKEN}`,
        'User-Agent': 'Node.js',
      },
    });

    const releaseId = releaseResponse.data.id;

    // 更新 Release 以关联 Milestone
    await axios.patch(
      `https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/${releaseId}`,
      {
        milestone: milestoneId,
      },
      {
        headers: {
          Authorization: `token ${GITHUB_TOKEN}`,
          'User-Agent': 'Node.js',
        },
      }
    );

    console.log('Milestone associated with release successfully!');
  } catch (error) {
    console.error('Failed to associate milestone:', error.message);
  }
}

associateMilestoneWithRelease();